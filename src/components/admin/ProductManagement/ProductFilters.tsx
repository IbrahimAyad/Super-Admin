import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { 
  Search, 
  Grid,
  List,
  AlertTriangle,
  ImageOff,
  EyeOff,
  Clock
} from 'lucide-react';

interface SmartFilters {
  lowStock: boolean;
  noImages: boolean;
  inactive: boolean;
  recentlyUpdated: boolean;
}

interface SmartFilterCounts {
  lowStock: number;
  noImages: number;
  inactive: number;
  recentlyUpdated: number;
}

interface ProductFiltersProps {
  // Search
  searchTerm: string;
  onSearchChange: (value: string) => void;
  
  // Category filter
  categoryFilter: string;
  onCategoryChange: (value: string) => void;
  categories: string[];
  
  // View mode
  viewMode: 'table' | 'grid';
  onViewModeChange: (mode: 'table' | 'grid') => void;
  
  // Smart filters
  smartFilters: SmartFilters;
  onSmartFilterToggle: (filterKey: keyof SmartFilters) => void;
  smartFilterCounts: SmartFilterCounts;
  
  // Styles
  styles?: {
    smartFiltersWrap?: string;
  };
}

export function ProductFilters({
  searchTerm,
  onSearchChange,
  categoryFilter,
  onCategoryChange,
  categories,
  viewMode,
  onViewModeChange,
  smartFilters,
  onSmartFilterToggle,
  smartFilterCounts,
  styles = {}
}: ProductFiltersProps) {
  const SmartFiltersBar = () => (
    <div className="flex flex-wrap gap-2">
      <Button
        variant={smartFilters.lowStock ? "default" : "outline"}
        size="sm"
        onClick={() => onSmartFilterToggle('lowStock')}
      >
        <AlertTriangle className="h-4 w-4 mr-1" />
        Low Stock ({smartFilterCounts.lowStock})
      </Button>
      <Button
        variant={smartFilters.noImages ? "default" : "outline"}
        size="sm"
        onClick={() => onSmartFilterToggle('noImages')}
      >
        <ImageOff className="h-4 w-4 mr-1" />
        No Images ({smartFilterCounts.noImages})
      </Button>
      <Button
        variant={smartFilters.inactive ? "default" : "outline"}
        size="sm"
        onClick={() => onSmartFilterToggle('inactive')}
      >
        <EyeOff className="h-4 w-4 mr-1" />
        Inactive ({smartFilterCounts.inactive})
      </Button>
      <Button
        variant={smartFilters.recentlyUpdated ? "default" : "outline"}
        size="sm"
        onClick={() => onSmartFilterToggle('recentlyUpdated')}
      >
        <Clock className="h-4 w-4 mr-1" />
        Recent ({smartFilterCounts.recentlyUpdated})
      </Button>
    </div>
  );

  return (
    <div className="space-y-4">
      {/* Search and Filters */}
      <div className="flex flex-col lg:flex-row lg:items-center gap-4">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Search products..."
            value={searchTerm}
            onChange={(e) => onSearchChange(e.target.value)}
            className="pl-9"
          />
        </div>
        <div className="flex flex-col sm:flex-row gap-2">
          <Select value={categoryFilter} onValueChange={onCategoryChange}>
            <SelectTrigger className="w-full sm:w-48">
              <SelectValue placeholder="All Categories" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Categories</SelectItem>
              {categories.map(category => (
                <SelectItem key={category} value={category}>{category}</SelectItem>
              ))}
            </SelectContent>
          </Select>
          <div className="flex items-center gap-2">
            <Button
              variant={viewMode === 'table' ? "default" : "outline"}
              size="sm"
              onClick={() => onViewModeChange('table')}
              className="hidden sm:flex"
            >
              <List className="h-4 w-4" />
            </Button>
            <Button
              variant={viewMode === 'grid' ? "default" : "outline"}
              size="sm"
              onClick={() => onViewModeChange('grid')}
              className="hidden sm:flex"
            >
              <Grid className="h-4 w-4" />
            </Button>
          </div>
        </div>
      </div>

      {/* Smart Filters */}
      <div className={`${styles.smartFiltersWrap || ''}`}>
        <SmartFiltersBar />
      </div>
    </div>
  );
}